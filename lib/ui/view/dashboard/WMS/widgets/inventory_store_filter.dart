import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/ui/components/custom_search_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const String kAllStores = "All stores";

/// Store picker shared by the Dashboard/Items/Stock screens. Inventory is
/// scoped by store_id (not by department/shop). Only active stores are
/// offered -- inactive/decommissioned ones (BEACON PRIDE KITCHEN, CC
/// KITCHEN, PACKING MATERIAL STORE as of the current data) aren't
/// meaningful choices to filter by. A search dialog replaces a plain
/// dropdown since the list runs to 15+ stores.
class InventoryStoreFilter extends StatefulWidget {
  const InventoryStoreFilter({
    super.key,
    required this.selectedStoreId,
    required this.onChanged,
  });

  final String? selectedStoreId;
  final void Function(String? storeId) onChanged;

  @override
  State<InventoryStoreFilter> createState() => _InventoryStoreFilterState();
}

class _InventoryStoreFilterState extends State<InventoryStoreFilter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<WMSController>();
      if (controller.storesModel == null && !controller.isStoresLoading) {
        controller.getStores(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WMSController>(
      builder: (context, controller, child) {
        final stores = (controller.storesModel?.data ?? [])
            .where((s) => s.isActive)
            .toList();
        final names = [kAllStores, ...stores.map((s) => s.name ?? "")];

        String selectedName = kAllStores;
        if (widget.selectedStoreId != null) {
          final matches = stores.where((s) => s.id == widget.selectedStoreId);
          selectedName = matches.isEmpty
              ? kAllStores
              : (matches.first.name ?? kAllStores);
        }

        return CustomSearchDropdown(
          hintText: kAllStores,
          fieldTitle: "Store",
          selectedItem: selectedName,
          menuList: names,
          onChange: (name) {
            if (name == kAllStores) {
              widget.onChanged(null);
              return;
            }
            final match = stores.where((s) => s.name == name);
            widget.onChanged(match.isEmpty ? null : match.first.id);
          },
        );
      },
    );
  }
}
