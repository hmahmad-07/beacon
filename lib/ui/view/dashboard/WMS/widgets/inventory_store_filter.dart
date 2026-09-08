import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/ui/components/custom_dropdown_.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const String kAllStores = "All stores";

/// Store picker shared by the Dashboard/Items/Stock screens. Inventory is
/// scoped by store_id (not by department/shop), and mirrors the store
/// dropdown on the reference web dashboard (104.143.0.113:8000).
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
        final stores = controller.storesModel?.data ?? [];
        final names = [kAllStores, ...stores.map((s) => s.name ?? "")];
        final selectedName = widget.selectedStoreId == null
            ? kAllStores
            : stores
                  .firstWhere(
                    (s) => s.id == widget.selectedStoreId,
                    orElse: () => stores.first,
                  )
                  .name;

        return CustomDropdown(
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
