import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/controllers/sales_controller.dart';
import '../../../../core/controllers/sales_period_controller.dart';
import '../../../../core/extensions/routes.dart';
import '../../../../core/extensions/sizer.dart';
import '../../../../core/models/Sales/sales_common.dart';
import '../../../../core/models/Sales/sales_ledger_directory.dart';
import '../../../../core/models/Sales/sales_models.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../components/custom_appbar.dart';
import 'sales_client_detail_view.dart';
import 'sales_ui.dart';
import 'sales_widgets.dart';

enum SalesClientKind { internal, external }

/// Internal and external clients for one business and period.
///
/// Two different relationships:
/// - Internal clients are the company's own outlets. Salespersons supply them
///   stock directly from the warehouse, so they are filtered by the
///   salesperson who created the bill.
/// - External clients are booked by an order booker, so they are filtered by
///   the order booker assigned to each client.
class SalesClientsScreen extends StatelessWidget {
  const SalesClientsScreen({
    super.key,
    required this.business,
    required this.filters,
    this.kind = SalesClientKind.internal,
    this.initialPickId,
    this.initialName,
  });

  final SalesBusiness business;
  final SalesFilters filters;
  final SalesClientKind kind;

  /// Salesperson to pre-select: a salesperson ID for internal clients, or an
  /// order-booker ID for external clients.
  final String? initialPickId;
  final String? initialName;

  @override
  Widget build(BuildContext context) {
    final internal = kind == SalesClientKind.internal;
    final pick = initialPickId ?? '';
    final scoped = filters.copyWith(
      salespersonId: internal ? pick : '',
      orderbookerId: internal ? '' : pick,
    );

    return ChangeNotifierProvider(
      create: (_) =>
          SalesController(business: business, initialFilters: scoped),
      child: _ClientsBody(
        kind: kind,
        initialPickId: initialPickId,
        initialName: initialName,
      ),
    );
  }
}

class _ClientsBody extends StatefulWidget {
  const _ClientsBody({
    required this.kind,
    required this.initialPickId,
    required this.initialName,
  });

  final SalesClientKind kind;
  final String? initialPickId;
  final String? initialName;

  @override
  State<_ClientsBody> createState() => _ClientsBodyState();
}

class _ClientsBodyState extends State<_ClientsBody> {
  static const _perPage = 50;

  late SalesClientKind _kind;
  String? _pickId;
  String? _pickName;
  final _search = TextEditingController();
  String _query = '';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _kind = widget.kind;
    _pickId = widget.initialPickId;
    _pickName = widget.initialName;

    final controller = context.read<SalesController>();
    // A period chosen anywhere in Sales reloads this list from page 1.
    controller.bindPeriod(context.read<SalesPeriodController>(), (_) async {
      if (mounted) setState(() => _page = 1);
      _load();
      controller.loadPickerOptions();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.loadPickerOptions();
      _load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load() {
    final controller = context.read<SalesController>();
    if (_kind == SalesClientKind.internal) {
      controller.loadInternalClients(page: _page, perPage: _perPage);
    } else {
      controller.loadExternalBookers(page: _page, perPage: _perPage);
      final bookerId = _pickId;
      if (bookerId != null) {
        controller.loadOrderBookerTrend(orderbookerId: bookerId);
      }
    }
  }

  /// Switching lists clears the salesperson filter, because the internal
  /// and external filters are different fields.
  void _setKind(SalesController controller, SalesClientKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _pickId = null;
      _pickName = null;
      _page = 1;
    });
    controller.setFilters(
      controller.filters.copyWith(salespersonId: '', orderbookerId: ''),
    );
    _load();
  }

  SalesFilters _withPick(SalesFilters filters, String? id) {
    return _kind == SalesClientKind.internal
        ? filters.copyWith(salespersonId: id ?? '')
        : filters.copyWith(orderbookerId: id ?? '');
  }

  Future<void> _changePeriod(SalesController controller) async {
    final next = await showSalesPeriodSheet(context, controller.filters);
    if (next == null || !mounted) return;
    context.read<SalesPeriodController>().setPeriod(next);
  }

  Future<void> _changeSalesperson(SalesController controller) async {
    final internal = _kind == SalesClientKind.internal;
    final choice = await showSalesPickerSheet(
      context,
      title: internal ? "Salesperson" : "Order booker",
      allLabel: internal ? "All salespersons" : "All order bookers",
      options: _options(controller),
      selectedId: _pickId,
    );
    if (choice == null || !mounted) return;
    final option = choice.option;
    setState(() {
      _pickId = option?.id;
      _pickName = option?.name;
      _page = 1;
    });
    controller.setFilters(_withPick(controller.filters, option?.id));
    _load();
  }

  /// Picker choices come from the directory endpoint, so they are never
  /// narrowed by the current selection.
  List<SalesPickerOption> _options(SalesController controller) {
    final directory = controller.directory;
    if (_kind == SalesClientKind.internal) {
      return [
        for (final person in directory?.salespersons ?? const <DirectorySalesperson>[])
          SalesPickerOption(
            id: '${person.salespersonId}',
            name: person.name,
            subtitle: person.isActive ? "Active" : "Inactive",
          ),
      ];
    }
    return [
      for (final booker in directory?.orderBookers ?? const <DirectoryBooker>[])
        if (!booker.isUnassigned)
          SalesPickerOption(
            id: booker.orderbookerId!,
            name: booker.name,
            subtitle: "${booker.clientCount} clients · ${booker.isActive ? 'Active' : 'Inactive'}",
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesController>(
      builder: (context, controller, _) {
        final accent = salesAccentFor(controller.business);
        final title = _pickName == null ? "Clients" : "Clients · $_pickName";

        return Scaffold(
          backgroundColor: AppColor.scaffold,
          appBar: CustomAppBar(title: title),
          body: RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
              children: [
                SalesSegmentedControl<SalesClientKind>(
                  value: _kind,
                  options: {
                    SalesClientKind.internal: "Internal clients",
                    SalesClientKind.external: "External clients",
                  },
                  onChanged: (kind) => _setKind(controller, kind),
                ),
                2.height,
                Row(
                  children: [
                    Expanded(
                      child: SalesPillButton(
                        icon: Icons.calendar_month_rounded,
                        label: salesPeriodLabel(controller.filters),
                        accent: accent,
                        onTap: () => _changePeriod(controller),
                      ),
                    ),
                    2.width,
                    Expanded(
                      child: SalesPillButton(
                        icon: Icons.person_search_rounded,
                        label: _pickName ??
                            (_kind == SalesClientKind.internal
                                ? "All salespersons"
                                : "All order bookers"),
                        accent: accent,
                        onTap: () => _changeSalesperson(controller),
                      ),
                    ),
                  ],
                ),
                2.height,
                _summary(controller, accent),
                if (_kind == SalesClientKind.external && _pickId != null) ...[
                  2.height,
                  _bookerTrendCard(controller, accent),
                ],
                2.height,
                _searchField(),
                2.height,
                _list(controller, accent),
                _pagination(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summary(SalesController controller, Color accent) {
    final summary = _kind == SalesClientKind.internal
        ? controller.internalClients?.summary
        : controller.externalBookers?.page.summary;
    final clients = salesInt(summary?['total_clients']);
    final sales = salesDouble(summary?['sales_amount']);
    final quantity = salesDouble(summary?['sales_quantity']);

    return SizedBox(
      height: 12.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SalesKpi(
              label: "Clients",
              value: "$clients",
              accent: accent,
              icon: Icons.groups_rounded,
            ),
          ),
          2.width,
          Expanded(
            child: SalesKpi(
              label: "Net sales",
              value: salesMoney(sales),
              caption: "${salesQty(quantity)} qty",
              accent: accent,
              icon: Icons.payments_rounded,
            ),
          ),
        ],
      ),
    );
  }

  /// The selected order booker's 12-month sales, from the dashboard scoped by
  /// `orderbooker_id`. Each external client's own monthly sales are on its
  /// client screen.
  Widget _bookerTrendCard(SalesController controller, Color accent) {
    final bookerId = _pickId!;
    final loaded = controller.bookerTrendId == bookerId;
    final d = loaded ? controller.bookerDashboard : null;

    if (controller.bookerLoading && (!loaded || d == null)) {
      return SizedBox(height: 24.h, child: const SalesLoadingState());
    }
    if (controller.bookerError != null && (!loaded || d == null)) {
      return SalesErrorState(
        message: controller.bookerError!,
        onRetry: () => controller.loadOrderBookerTrend(orderbookerId: bookerId),
      );
    }
    if (d == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalesSectionTitle(
          "${_pickName ?? 'Order booker'} · monthly sales",
        ),
        SalesCard(
          child: SalesBarChart(
            accent: accent,
            bars: salesBarsFrom(d.monthlyTrend, salesMonthKeyLabel),
          ),
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: "Search name or ID on this page",
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColor.white,
        contentPadding: EdgeInsets.symmetric(vertical: 1.4.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _list(SalesController controller, Color accent) {
    final internal = _kind == SalesClientKind.internal;
    final loading = internal
        ? controller.internalLoading
        : controller.externalLoading;
    final error = internal ? controller.internalError : controller.externalError;
    final hasPage = internal
        ? controller.internalClients != null
        : controller.externalBookers != null;

    if (loading && !hasPage) {
      return SizedBox(height: 30.h, child: const SalesLoadingState());
    }
    if (error != null && !hasPage) {
      return SalesErrorState(message: error, onRetry: _load);
    }

    final all = _rows(controller);
    if (all.isEmpty) {
      return const SalesEmptyState(message: "No clients for this period.");
    }
    final visible = _query.isEmpty
        ? all
        : all
              .where(
                (row) =>
                    row.name.toLowerCase().contains(_query) ||
                    row.id.toLowerCase().contains(_query),
              )
              .toList();
    if (visible.isEmpty) {
      return const SalesEmptyState(message: "No clients match your search.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in visible)
          Padding(
            padding: EdgeInsets.only(bottom: 1.2.h),
            child: SalesRowCard(
              title: row.name,
              subtitle: row.subtitle,
              trailingValue: salesMoney(row.amount),
              trailingCaption: "${salesQty(row.quantity)} qty",
              accent: accent,
              comparison: row.comparison,
              onTap: () => AppRoutes.push(
                SalesClientDetailScreen(
                  business: controller.business,
                  filters: controller.filters,
                  clientId: row.id,
                  clientName: row.name,
                  subtitle: row.subtitle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_ClientRow> _rows(SalesController controller) {
    if (_kind == SalesClientKind.internal) {
      return [
        for (final client
            in controller.internalClients?.items ?? const <InternalClientSales>[])
          _ClientRow(
            id: client.clientId,
            name: client.clientName,
            subtitle: "${client.clientId} · ${client.isActive ? 'Active' : 'Inactive'}",
            amount: client.totals.salesAmount,
            quantity: client.totals.salesQuantity,
            comparison: client.comparison,
          ),
      ];
    }
    return [
      for (final client
          in controller.externalBookers?.page.items ?? const <ExternalClientSales>[])
        _ClientRow(
          id: client.clientId,
          name: client.clientName,
          subtitle: "${client.clientId} · ${client.orderbookerName}",
          amount: client.totals.salesAmount,
          quantity: client.totals.salesQuantity,
          comparison: client.comparison,
        ),
    ];
  }

  Widget _pagination(SalesController controller) {
    final meta = _kind == SalesClientKind.internal
        ? controller.internalClients?.meta
        : controller.externalBookers?.page.meta;
    if (meta == null) return const SizedBox.shrink();
    return SalesPaginationBar(
      meta: meta,
      onPage: (next) {
        setState(() => _page = next);
        _load();
      },
    );
  }
}

class _ClientRow {
  const _ClientRow({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.quantity,
    required this.comparison,
  });

  final String id;
  final String name;
  final String subtitle;
  final double amount;
  final double quantity;
  final SalesComparison comparison;
}
