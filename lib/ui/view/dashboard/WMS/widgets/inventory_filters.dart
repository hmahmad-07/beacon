import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_store_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_field.dart';
import 'package:beacon/ui/components/custom_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Compact filter system shared by every inventory screen:
//
//   [ 🔍 Search…            ✕ ] [⚙ 2]   <- one row: search + filter button
//   (Store: CC STORE ✕) (1 Sep – 25 Sep ✕)   <- only the active filters
//
// Everything else lives in a bottom sheet (showInventoryFilterSheet) whose
// choices are drafted locally and applied with one fetch on "Show results".

const kAllStoresLabel = "All stores";

String formatRangeLabel(DateTimeRange r) {
  final f = DateFormat('d MMM');
  final sameYear = r.start.year == r.end.year;
  final end = DateFormat(sameYear ? 'd MMM' : 'd MMM yy').format(r.end);
  return "${f.format(r.start)} – $end";
}

// ------------------------------------------------------------ Search bar

class InventorySearchBar extends StatefulWidget {
  const InventorySearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.accentColor,
    this.onSubmitted,
    this.onChanged,
    this.onFilterTap,
    this.activeFilterCount = 0,
  });

  final TextEditingController controller;
  final String hintText;
  final Color accentColor;

  /// Server-side search: fires on the keyboard's search action and when
  /// the clear button empties the field.
  final ValueChanged<String>? onSubmitted;

  /// Local, as-you-type filtering (e.g. the stores list).
  final ValueChanged<String>? onChanged;

  /// Shows the filter button when set.
  final VoidCallback? onFilterTap;
  final int activeFilterCount;

  @override
  State<InventorySearchBar> createState() => _InventorySearchBarState();
}

class _InventorySearchBarState extends State<InventorySearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call("");
    widget.onSubmitted?.call("");
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    // The filter button stretches to the field's exact height. CustomField
    // reserves a 2.5.h gap above itself (no fieldTitle), so the button
    // skips the same gap.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomField(
              controller: widget.controller,
              hintText: widget.hintText,
              isLabel: false,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
              prefix: Icon(
                Icons.search_rounded,
                color: AppColor.grey,
                size: 5.w,
              ),
              suffixIcon: hasText
                  ? GestureDetector(
                      onTap: _clear,
                      child: Icon(
                        Icons.close_rounded,
                        size: 5.w,
                        color: AppColor.grey,
                      ),
                    )
                  : null,
            ),
          ),
          if (widget.onFilterTap != null) ...[
            2.width,
            Padding(
              padding: EdgeInsets.only(top: 2.5.h),
              child: AspectRatio(
                aspectRatio: 1,
                child: _FilterButton(
                  accentColor: widget.accentColor,
                  count: widget.activeFilterCount,
                  onTap: widget.onFilterTap!,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.accentColor,
    required this.count,
    required this.onTap,
  });

  final Color accentColor;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Tooltip(
      message: "Filters",
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: active ? accentColor : AppColor.white,
              borderRadius: BorderRadius.circular(3.r),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(3.r),
                child: Container(
                  alignment: Alignment.center,
                  // Matches CustomField's enabled border.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.r),
                    border: Border.all(
                      color: active ? accentColor : AppColor.appLightColor,
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 5.5.w,
                    color: active ? AppColor.white : accentColor,
                  ),
                ),
              ),
            ),
          ),
          if (active)
            Positioned(
              top: -0.6.h,
              right: -1.w,
              child: Container(
                padding: EdgeInsets.all(1.w),
                constraints: BoxConstraints(minWidth: 4.8.w),
                decoration: BoxDecoration(
                  color: AppColor.appDarkColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.white, width: 1.5),
                ),
                child: Text(
                  "$count",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 2.4.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Active chips

class InventoryActiveFilter {
  const InventoryActiveFilter({
    required this.icon,
    required this.label,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final VoidCallback onRemove;
}

/// Only renders when something is active, so an unfiltered screen gives
/// the whole viewport to data.
class InventoryActiveFilterChips extends StatelessWidget {
  const InventoryActiveFilterChips({
    super.key,
    required this.filters,
    required this.accentColor,
    this.onClearAll,
  });

  final List<InventoryActiveFilter> filters;
  final Color accentColor;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 1.4.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in filters) ...[_chip(f), 2.width],
            if (filters.length > 1 && onClearAll != null)
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Clear all",
                  style: TextStyle(
                    fontSize: 3.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(InventoryActiveFilter f) {
    return Container(
      padding: EdgeInsets.only(left: 2.8.w, top: 0.7.h, bottom: 0.7.h),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(f.icon, size: 3.6.w, color: accentColor),
          1.4.width,
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 45.w),
            child: Text(
              f.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 2.9.sp,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
          InkWell(
            onTap: f.onRemove,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.8.w),
              child: Icon(Icons.close_rounded, size: 3.8.w, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Filter sheet

/// Bottom sheet scaffold: grab handle, "Filters" + Reset header, the
/// screen's sections, and a sticky "Show results" button. Sections read
/// the caller's draft variables and call `setSheet` to rebuild.
Future<void> showInventoryFilterSheet({
  required BuildContext context,
  required Color accentColor,
  required List<Widget> Function(BuildContext context, StateSetter setSheet)
  sections,
  required VoidCallback onReset,
  required VoidCallback onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColor.scaffold,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheet) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 1.2.h),
              child: Container(
                width: 11.w,
                height: 0.55.h,
                decoration: BoxDecoration(
                  color: AppColor.appLightColor,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(5.w, 1.4.h, 2.w, 0.6.h),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: accentColor, size: 5.5.w),
                  2.5.width,
                  Expanded(
                    child: Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 4.6.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      onReset();
                      setSheet(() {});
                    },
                    icon: Icon(
                      Icons.restart_alt_rounded,
                      size: 4.6.w,
                      color: AppColor.grey,
                    ),
                    label: Text(
                      "Reset",
                      style: TextStyle(
                        fontSize: 3.3.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColor.appLightColor),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
                children: sections(context, setSheet),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 1.6.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 6.4.h,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.5.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onApply();
                    },
                    icon: Icon(Icons.check_rounded, size: 5.w),
                    label: Text(
                      "Show results",
                      style: TextStyle(
                        fontSize: 3.8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class InventoryFilterSection extends StatelessWidget {
  const InventoryFilterSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 2.7.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColor.grey,
            ),
          ),
          1.height,
          child,
        ],
      ),
    );
  }
}

/// Tappable row: leading icon, current value (or placeholder), and either
/// a chevron or -- when a value is set and [onClear] given -- a clear ✕.
class InventoryFilterTile extends StatelessWidget {
  const InventoryFilterTile({
    super.key,
    required this.icon,
    required this.placeholder,
    required this.accentColor,
    required this.onTap,
    this.value,
    this.onClear,
  });

  final IconData icon;
  final String placeholder;
  final String? value;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(3.5.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3.5.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.5.r),
            border: Border.all(
              color: hasValue
                  ? accentColor.withValues(alpha: 0.5)
                  : AppColor.appLightColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 4.5.w, color: accentColor),
              ),
              3.width,
              Expanded(
                child: Text(
                  value ?? placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.5.sp,
                    fontWeight: hasValue ? FontWeight.bold : FontWeight.w500,
                    color: hasValue ? AppColor.appDarkColor : AppColor.grey,
                  ),
                ),
              ),
              if (hasValue && onClear != null)
                InkWell(
                  onTap: onClear,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(1.w),
                    child: Icon(
                      Icons.close_rounded,
                      size: 5.w,
                      color: AppColor.grey,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 5.5.w,
                  color: AppColor.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-select pill group (status, sort order, ...).
class InventoryChoiceChips<T> extends StatelessWidget {
  const InventoryChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.accentColor,
  });

  /// value -> (label, icon)
  final Map<T, (String, IconData)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: options.entries.map((e) {
        final isSelected = e.key == selected;
        return InkWell(
          onTap: () => onChanged(e.key),
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.1.h),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : AppColor.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? accentColor : AppColor.appLightColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_rounded : e.value.$2,
                  size: 4.w,
                  color: isSelected ? AppColor.white : AppColor.grey,
                ),
                1.5.width,
                Text(
                  e.value.$1,
                  style: TextStyle(
                    fontSize: 3.2.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColor.white : AppColor.appDarkColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class InventorySwitchTile extends StatelessWidget {
  const InventorySwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.3.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        border: Border.all(color: AppColor.appLightColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(1.8.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 4.5.w, color: accentColor),
          ),
          3.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 3.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.appDarkColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
                  ),
              ],
            ),
          ),
          CustomToggleSwitch(
            value: value,
            activeColor: accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Store picker

/// Searchable store list in a bottom sheet. Returns null when dismissed;
/// otherwise a record whose storeId is null for "All stores".
Future<({String? storeId})?> showInventoryStorePicker(
  BuildContext context, {
  required String? selectedStoreId,
  required Color accentColor,
}) {
  context.read<WMSController>().ensureStoresLoaded(context);
  return showModalBottomSheet<({String? storeId})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColor.scaffold,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
    ),
    builder: (_) => _StorePickerSheet(
      selectedStoreId: selectedStoreId,
      accentColor: accentColor,
    ),
  );
}

class _StorePickerSheet extends StatefulWidget {
  const _StorePickerSheet({
    required this.selectedStoreId,
    required this.accentColor,
  });

  final String? selectedStoreId;
  final Color accentColor;

  @override
  State<_StorePickerSheet> createState() => _StorePickerSheetState();
}

class _StorePickerSheetState extends State<_StorePickerSheet> {
  final _search = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Consumer<WMSController>(
        builder: (context, controller, _) {
          final q = _query.toLowerCase();
          final stores = controller.activeStores
              .where(
                (s) =>
                    q.isEmpty ||
                    (s.name ?? "").toLowerCase().contains(q) ||
                    (s.code ?? "").toLowerCase().contains(q),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1.2.h),
                child: Container(
                  width: 11.w,
                  height: 0.55.h,
                  decoration: BoxDecoration(
                    color: AppColor.appLightColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(5.w, 1.6.h, 5.w, 1.2.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      color: widget.accentColor,
                      size: 5.5.w,
                    ),
                    2.5.width,
                    Text(
                      "Select store",
                      style: TextStyle(
                        fontSize: 4.6.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: InventorySearchBar(
                  controller: _search,
                  hintText: "Search store name or code…",
                  accentColor: widget.accentColor,
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              1.2.height,
              Expanded(
                child: controller.isStoresLoading && stores.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          color: widget.accentColor,
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(5.w, 0.5.h, 5.w, 3.h),
                        children: [
                          if (q.isEmpty)
                            _row(
                              icon: Icons.select_all_rounded,
                              title: kAllStoresLabel,
                              subtitle:
                                  "${controller.activeStores.length} active stores",
                              selected: widget.selectedStoreId == null,
                              onTap: () =>
                                  Navigator.pop(context, (storeId: null)),
                            ),
                          for (final s in stores) _storeRow(context, s),
                          if (stores.isEmpty && q.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Center(
                                child: Text(
                                  "No stores match \"$_query\"",
                                  style: TextStyle(
                                    fontSize: 3.3.sp,
                                    color: AppColor.grey,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _storeRow(BuildContext context, InventoryStore s) {
    return _row(
      icon: Icons.store_mall_directory_outlined,
      title: s.name ?? "",
      subtitle: (s.code ?? "").isEmpty ? null : s.code,
      selected: s.id == widget.selectedStoreId,
      onTap: () => Navigator.pop(context, (storeId: s.id)),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Material(
        color: selected
            ? widget.accentColor.withValues(alpha: 0.08)
            : AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3.5.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.4.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.5.r),
              border: Border.all(
                color: selected ? widget.accentColor : AppColor.appLightColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 5.w,
                  color: selected ? widget.accentColor : AppColor.grey,
                ),
                3.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 3.5.sp,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: AppColor.appDarkColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 2.8.sp,
                            color: AppColor.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 5.w,
                    color: widget.accentColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact "🏬 CC STORE ▾" pill for screens whose only filter is the
/// store (dashboard).
class InventoryStoreChip extends StatelessWidget {
  const InventoryStoreChip({
    super.key,
    required this.selectedStoreId,
    required this.onChanged,
    required this.accentColor,
  });

  final String? selectedStoreId;
  final ValueChanged<String?> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final name =
        context.select<WMSController, String?>(
          (c) => c.storeNameById(selectedStoreId),
        ) ??
        kAllStoresLabel;
    final active = selectedStoreId != null;

    return Material(
      color: active ? accentColor.withValues(alpha: 0.1) : AppColor.white,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () async {
          final picked = await showInventoryStorePicker(
            context,
            selectedStoreId: selectedStoreId,
            accentColor: accentColor,
          );
          if (picked != null && picked.storeId != selectedStoreId) {
            onChanged(picked.storeId);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.1.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: active
                  ? accentColor.withValues(alpha: 0.4)
                  : AppColor.appLightColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_rounded, size: 4.4.w, color: accentColor),
              2.width,
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 55.w),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.3.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
              ),
              1.width,
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 5.w,
                color: AppColor.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
